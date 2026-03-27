class CreateMakeupFasts < ActiveRecord::Migration[8.1]
  def change
    create_table :makeup_fasts do |t|
      t.references :user, null: false, foreign_key: true
      t.date :fasted_on, null: false
      t.text :notes

      t.timestamps
    end
  end
end
