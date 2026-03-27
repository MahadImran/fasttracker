class CreateMakeupAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :makeup_allocations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :makeup_fast, null: false, foreign_key: true, index: false
      t.string :allocatable_type, null: false
      t.bigint :allocatable_id, null: false

      t.timestamps
    end

    add_index :makeup_allocations, [ :allocatable_type, :allocatable_id ]
    add_index :makeup_allocations, :makeup_fast_id, unique: true
  end
end
