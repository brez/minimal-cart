# See LICENSE file in the root for details
class MinimalCartGenerator < Rails::Generator::NamedBase
  
  def manifest
    record do |m|
      m.migration_template 'migration.rb', 
        'db/migrate', 
        :assigns => { :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}" }, 
        :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
    end
  end
  
  protected
    # Override with your own usage banner.
    def banner
      "Usage: #{$0} minimal_cart"
    end
end
