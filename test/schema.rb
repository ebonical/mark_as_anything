ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string :name
    t.timestamps
  end
  
  create_table :messages, :force => true do |t|
    t.string :subject
    t.timestamps
  end
  
  create_table :object_markers, :force => true do |t|
    t.integer :markable_id,   :null => false
    t.string  :markable_type, :null => false
    t.string  :marker,        :null => false
    t.integer :actor_id,      :null => false
    t.timestamps
  end
end
