class CreateObjectMarkers < ActiveRecord::Migration
  def self.up
    create_table :object_markers, :force => true do |t|
      t.integer :markable_id,   :null => false
      t.string  :markable_type, :null => false
      t.string  :marker,        :null => false
      t.integer :actor_id,      :null => false
      t.timestamps
    end
    
    add_index :object_markers, [:markable_id, :markable_type, :marker, :actor_id], :unique => true, :name => "index_object_markers_on_everything"
  end
  
  def self.down
    drop_table :object_markers
  end
end