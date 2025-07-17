class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :surname, :string
    add_column :users, :mobile_number, :string
    add_column :users, :address, :text
    add_column :users, :age, :integer
    add_column :users, :gender, :string
  end
end
