class HashApiKeyTokens < ActiveRecord::Migration[8.1]
  def change
    # PostgreSQL automatically renames the associated unique index when a column is renamed.
    rename_column :api_keys, :token, :token_digest
  end
end
