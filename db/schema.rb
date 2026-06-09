# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_09_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_api_keys_on_active"
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
  end

  create_table "geolocations", force: :cascade do |t|
    t.string "city"
    t.string "continent_code"
    t.string "continent_name"
    t.string "country_code"
    t.string "country_name"
    t.datetime "created_at", null: false
    t.string "ip_address", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.jsonb "raw_data", default: {}
    t.string "region_code"
    t.string "region_name"
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "zip"
    t.index ["ip_address"], name: "index_geolocations_on_ip_address", unique: true
    t.index ["raw_data"], name: "index_geolocations_on_raw_data", using: :gin
    t.index ["url"], name: "index_geolocations_on_url"
  end
end
