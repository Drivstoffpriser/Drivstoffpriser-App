"""Import stations from a JSON file into Firestore, skipping duplicates.

Creates a backup of all existing stations before making any changes.

Usage:
    FIREBASE_SERVICE_ACCOUNT_JSON='...' python scripts/import_stations.py /path/to/stations.json

Environment variables:
    FIREBASE_SERVICE_ACCOUNT_JSON  - Service account JSON string (required)
"""

import json
import os
import sys
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore


def backup_stations(db, backup_dir='backups'):
    """Backup all existing stations to a timestamped JSON file.

    Reads from the stations collection (source of truth), not the aggregate,
    to ensure the backup and duplicate-check are accurate.
    """
    os.makedirs(backup_dir, exist_ok=True)

    # Read from stations collection (source of truth)
    existing = [doc.to_dict() for doc in db.collection('stations').stream()]

    timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
    backup_path = os.path.join(backup_dir, f'stations_backup_{timestamp}.json')

    with open(backup_path, 'w', encoding='utf-8') as f:
        json.dump({
            'backedUpAt': datetime.now(timezone.utc).isoformat(),
            'count': len(existing),
            'stations': existing,
        }, f, indent=2, ensure_ascii=False)

    print(f'Backup saved: {backup_path} ({len(existing)} stations)')
    return {s['id'] for s in existing if 'id' in s}


def import_stations(db, import_path, existing_ids):
    """Import new stations from JSON, skipping any that already exist."""
    with open(import_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    stations = data.get('stations', [])
    print(f'Import file contains {len(stations)} stations')

    new_stations = [s for s in stations if s['id'] not in existing_ids]
    skipped = len(stations) - len(new_stations)
    print(f'Skipping {skipped} duplicates, importing {len(new_stations)} new stations')

    if not new_stations:
        print('Nothing to import.')
        return 0

    # Firestore batches are limited to 500 operations
    batch_size = 500
    for i in range(0, len(new_stations), batch_size):
        chunk = new_stations[i:i + batch_size]
        batch = db.batch()
        for station in chunk:
            ref = db.collection('stations').document(station['id'])
            batch.set(ref, station)
        batch.commit()
        print(f'  Wrote batch {i // batch_size + 1}: {len(chunk)} stations')

    return len(new_stations)


def rebuild_stations_aggregate(db):
    """Rebuild the stations aggregate doc from all station documents."""
    print('Rebuilding stations aggregate...')
    docs = db.collection('stations').stream()
    all_stations = [doc.to_dict() for doc in docs]

    db.collection('aggregates').document('stations').set({
        'stations': all_stations,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    })
    print(f'Aggregate rebuilt with {len(all_stations)} stations')


def main():
    if len(sys.argv) < 2:
        print('Usage: python scripts/import_stations.py <stations.json>')
        sys.exit(1)

    import_path = sys.argv[1]
    if not os.path.isfile(import_path):
        print(f'Error: File not found: {import_path}')
        sys.exit(1)

    service_account_json = os.environ.get('FIREBASE_SERVICE_ACCOUNT_JSON')
    if not service_account_json:
        print('Error: FIREBASE_SERVICE_ACCOUNT_JSON not set.')
        sys.exit(1)

    service_account_info = json.loads(service_account_json)
    cred = credentials.Certificate(service_account_info)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    # Step 1: Backup existing stations
    print('=== Step 1: Backup ===')
    existing_ids = backup_stations(db)

    # Step 2: Import new stations (skip duplicates)
    print('\n=== Step 2: Import ===')
    imported = import_stations(db, import_path, existing_ids)

    # Step 3: Rebuild aggregate if anything was imported
    if imported > 0:
        print('\n=== Step 3: Rebuild Aggregate ===')
        rebuild_stations_aggregate(db)

    print(f'\nDone. {imported} new stations added.')


if __name__ == '__main__':
    main()
