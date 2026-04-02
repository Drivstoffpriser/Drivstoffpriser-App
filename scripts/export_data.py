"""Export Firestore station and price data to static JSON files for public access."""

import json
import os
import sys
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore


def main():
    service_account_json = os.environ.get('FIREBASE_SERVICE_ACCOUNT_JSON')
    if not service_account_json:
        print('Error: FIREBASE_SERVICE_ACCOUNT_JSON not set.')
        sys.exit(1)

    service_account_info = json.loads(service_account_json)
    cred = credentials.Certificate(service_account_info)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    os.makedirs('docs/data', exist_ok=True)

    # Export stations from the stations collection (source of truth).
    # This also self-heals the aggregate if it has drifted.
    stations = [doc.to_dict() for doc in db.collection('stations').stream()]

    # Rebuild aggregate to stay in sync
    db.collection('aggregates').document('stations').set({
        'stations': stations,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    })
    print(f'Exported {len(stations)} stations')

    # Export prices
    prices_doc = db.collection('aggregates').document('prices').get()
    prices = []
    if prices_doc.exists:
        data = prices_doc.to_dict()
        prices = data.get('prices', [])
    print(f'Exported {len(prices)} prices')

    now = datetime.now(timezone.utc).isoformat()

    with open('docs/data/stations.json', 'w') as f:
        json.dump({
            'exportedAt': now,
            'count': len(stations),
            'stations': stations,
        }, f, indent=2, default=str)

    with open('docs/data/prices.json', 'w') as f:
        json.dump({
            'exportedAt': now,
            'count': len(prices),
            'prices': prices,
        }, f, indent=2, default=str)

    print(f'Data exported at {now}')


if __name__ == '__main__':
    main()
