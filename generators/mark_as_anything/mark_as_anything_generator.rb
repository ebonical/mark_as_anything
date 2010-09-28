class MarkAsAnythingGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template "create_object_markers.rb", "db/migrate", :migration_file_name => "create_object_markers"
    end
  end
end