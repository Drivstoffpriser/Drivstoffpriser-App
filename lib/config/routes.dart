/*
* A crowdsourced platform for real-time fuel price monitoring in Norway
* Copyright (C) 2026  Tsotne Karchava & Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String stationDetail = '/station';
  static const String submitPrice = '/submit-price';
  static const String auth = '/auth';
  static const String bugReport = '/bug-report';
  static const String addStation = '/add-station';
  static const String myStationSubmissions = '/my-station-submissions';
  static const String adminSubmissions = '/admin-submissions';
  static const String adminModifyRequests = '/admin-modify-requests';
  static const String manageAdmins = '/manage-admins';
}
