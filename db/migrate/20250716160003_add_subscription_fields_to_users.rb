class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :subscription_id, :string
    add_column :users, :subscription_status, :string
  end
end
