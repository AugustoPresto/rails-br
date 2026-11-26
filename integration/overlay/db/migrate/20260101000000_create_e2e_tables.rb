class CreateE2eTables < ActiveRecord::Migration[6.0]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :cpf
      t.string :cnpj
      t.string :pix_key
      t.date :birth_on
      t.decimal :credit_limit, precision: 12, scale: 2
    end

    create_table :orders do |t|
      t.references :customer
      t.decimal :amount, precision: 14, scale: 2
      t.date :due_on
    end

    # Coluna com mais de 2 casas, comum em sistemas contábeis.
    create_table :entries do |t|
      t.decimal :amount, precision: 16, scale: 4
    end
  end
end
