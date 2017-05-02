class CreateTeams < ActiveRecord::Migration[5.0]
  def change
    create_table :teams do |t|
      t.string :slack_id, null: false
      t.string :slack_token, null: false
      t.timestamps
    end
  end
end
