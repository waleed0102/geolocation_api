class CreateGeolocations < ActiveRecord::Migration[8.1]
  def change
    create_table :geolocations do |t|
      t.string :ip_address, null: false
      t.string :url
      t.string :continent_code
      t.string :continent_name
      t.string :country_code
      t.string :country_name
      t.string :region_code
      t.string :region_name
      t.string :city
      t.string :zip
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.jsonb :raw_data, default: {}

      t.timestamps
    end

    add_index :geolocations, :ip_address, unique: true
    add_index :geolocations, :url
    add_index :geolocations, :raw_data, using: :gin
  end
end
