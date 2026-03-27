class CreateRamadanSeasonBalances < ActiveRecord::Migration[8.1]
  def change
    create_table :ramadan_season_balances do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :gregorian_year
      t.integer :hijri_year
      t.integer :owed_count, null: false, default: 0
      t.text :notes

      t.timestamps
    end
  end
end
