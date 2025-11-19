# Plant Sample Tracker

A simple desktop application built with Flutter for researchers to log, track, and manage plant sample data. The app connects to a Supabase backend, which provides a PostgreSQL database and an auto-generated API.

## 🚀 Core Features

* **Add New Samples:** A form-based system allows users to create new sample entries.
    * **Auto-Location:** Automatically captures the user's current GPS coordinates (latitude and longitude) using the device's location services.
    * **Auto-Date:** Automatically logs the current date and time of sampling.
    * **Dynamic Forms:** Uses pre-populated dropdown menus to select the researcher and plant species.
    * **Flexible Data:** Users can input specific details (like height) and environmental conditions (like soil pH and humidity), which are stored in JSONB fields in the database.

* **Manage Existing Samples:** Users can manage samples by looking them up with their unique **Sample ID**.
    * **Query:** Fetch and display all details for a specific sample, including the name of the researcher who collected it.
    * **Update:** Load an existing sample's data into an "Edit" form, allowing the user to modify and save any changes.
    * **Delete:** Permanently remove a sample record from the database.

## 🛠️ Technology Stack

* **Frontend:** Flutter
* **Backend (BaaS):** Supabase
* **Database:** PostgreSQL (managed by Supabase)
* **Key Flutter Packages:**
    * `supabase_flutter`: For all database (CRUD) operations and API calls.
    * `geolocator`: For fetching the device's GPS coordinates.
