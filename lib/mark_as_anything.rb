require "object_marker"

module MarkAsAnything
  mattr_accessor :actor
  
  BY_REGEX = /^is_(\w+)_by\?$/
  MARK_REGEX = /^mark_as_(\w+)_by$/
  UNMARK_REGEX = /^unmark_as_(\w+)_by$/
  UNMARK_ALL_REGEX = /^unmark_as_(\w+)_by_all$/
  HAS_REGEX = /^has_(\w+)\?$/
  
  def self.included(receiver)
    receiver.extend ClassMethods
  end
  
  module ClassMethods
    def markable_with(*markers)
      extend MarkAsAnything::MarkableMethods::ClassMethods
      include MarkAsAnything::MarkableMethods::InstanceMethods
      
      self.markable_markers += markers.map { |m| m.to_s }
      
      has_many :object_markers, :as => :markable, :dependent => :delete_all
      
      # named scope example Message::read_by(user)
      markable_markers.each do |marker|
        class_eval <<-end_eval
          named_scope :#{marker}_by, lambda { |actor| 
            { :conditions => ["object_markers.marker = ? AND object_markers.actor_id = ?", '#{marker}', actor], 
              :include => :object_markers } 
          }
        end_eval
      end
    end
    
    # To be inserted into the model that will be marking things.
    # Likely to be a _User_ model.
    # TODO use this knowledge to allow different classes other than User
    def markable_actor
      MarkAsAnything.actor = self
      include MarkAsAnything::MarkableActorMethods::InstanceMethods
    end
  end
  
  # Methods for the markable object
  module MarkableMethods
    
    module ClassMethods
      def markable_markers=(value)
        @markable_markers = [value].flatten
      end
      
      def markable_markers
        init_markable_markers unless @markable_markers_initialised
        @markable_markers
      end
      
      private 
      
      # makes markers safe to inherit
      def init_markable_markers
        @markable_markers_initialised = true
        @markable_markers = superclass.respond_to?(:markable_markers) ? superclass.markable_markers.dup : []
      end
    end
    
    module InstanceMethods
      
      def respond_to?(sym, include_private=false)
        [MarkAsAnything::BY_REGEX, MarkAsAnything::MARK_REGEX, MarkAsAnything::UNMARK_REGEX, MarkAsAnything::UNMARK_ALL_REGEX].each do |pattern|
          if sym.to_s.match(pattern)
            return has_marker?($1) || super
          end
        end
        super
      end
      
      def method_missing(sym, *args)
        [MarkAsAnything::BY_REGEX, MarkAsAnything::MARK_REGEX, MarkAsAnything::UNMARK_REGEX, MarkAsAnything::UNMARK_ALL_REGEX].each_with_index do |pattern, idx|
          if sym.to_s.match(pattern) && has_marker?($1)
            marker = $1
            actor = args.first
            return case idx
              when 0 then is_marked_with?(marker, actor)
              when 1 then mark_object(marker, actor)
              when 2 then unmark_object(marker, actor)
              when 3 then unmark_object_for_all(marker)
            end
          end
        end
        super
      end
      
      private
      
      # test a "is_somethinged_by?" like method
      def is_marked_with?(marker, actor)
        cached_value = markable_cache(marker, actor)
        cached_value.nil? ? 
          markable_cache(marker, actor, !object_markers.find_by_marker_and_actor_id(marker, actor).nil?) : 
          cached_value
      end
      
      def mark_object(marker, actor)
        unless send("is_#{marker}_by?", actor)
          markable_cache(marker, actor, true)
          object_markers.create(:actor => actor, :marker => marker)
        end
      end
      
      def unmark_object(marker, actor)
        if found = object_markers.find_by_marker_and_actor_id(marker, actor)
          markable_cache(marker, actor, false)
          found.destroy
        end
      end
      
      def unmark_object_for_all(marker)
        clear_markable_cache(marker)
        if !(found = object_markers.find_all_by_marker(marker)).empty?
          ObjectMarker.delete_all(["id IN (?)", found])
        end
      end
      
      def has_marker?(marker)
        self.class.markable_markers.include?(marker.to_s)
      end
      
      def markable_cache(marker, actor, set_value = nil)
        @_markable_cache ||= {}
        @_markable_cache[marker] ||= {}
        @_markable_cache[marker][actor] = set_value if !set_value.nil?
        @_markable_cache[marker][actor]
      end
      
      def clear_markable_cache(marker)
        @_markable_cache[marker] = {}
      rescue
        nil
      end
    end
    
  end
  
  # Methods for the actor who is marking objects (probably a User model)
  module MarkableActorMethods
    module InstanceMethods
      # Catch has_XXX? checks
      # e.g. some_user.has_read?(some_message)
      def method_missing(sym, *args)
        if match = sym.to_s.match(MarkAsAnything::HAS_REGEX)
          object = args.first
          if object.respond_to?("is_#{match[1]}_by?")
            object.send("is_#{match[1]}_by?", self)
          else
            super
          end
        else
          super
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, MarkAsAnything)
