class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :stripe_subscription_id
      t.integer :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
