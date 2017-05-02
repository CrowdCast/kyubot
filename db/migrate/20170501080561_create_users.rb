class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :slack_name, null: false
      t.text :description, null: true
      t.decimal :allowance, scale:2, precision:4, null: false, default:0
      t.decimal :days_taken, scale:2, precision:4, null: false, default:0
      t.boolean :is_approver, null: false, default: false
      # t.boolean :is_deleted
      t.string :slack_id, null: false
      t.timestamps

      t.references :team, index:true
    end
    add_foreign_key :users, :teams
  end
end
