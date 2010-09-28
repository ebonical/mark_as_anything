class ObjectMarker < ActiveRecord::Base
  belongs_to :markable, :polymorphic => true
  
  # TODO make actor :class_name definable 
  belongs_to :actor, :class_name => "User", :foreign_key => "actor_id"
end
