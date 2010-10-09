class CommentsExtension < Radiant::Extension
  version "#{File.read(File.expand_path(File.dirname(__FILE__)) + '/VERSION')}"
  description "Adds blog-like comments and comment functionality to pages."
  url "http://github.com/saturnflyer/radiant-comments"
  
  extension_config do |config|
    config.gem 'sanitize'
    config.gem 'mollom'
  end

  def activate
    Dir["#{File.dirname(__FILE__)}/app/models/*_filter.rb"].each do |file|
      require file
    end

    Page.class_eval do
      include CommentPageExtensions
      include CommentTags
    end

    if admin.respond_to? :page
      admin.page.edit.add :parts_bottom, "edit_comments_enabled", :before => "edit_timestamp"
      admin.page.index.add :sitemap_head, "index_head_view_comments"
      admin.page.index.add :node, "index_view_comments"
		  admin.page.edit.add :parts_bottom, "edit_enable_blog_directory"
		  admin.page.index.add :sitemap_head, "index_head_view_posted_time_user", :after => "title_column_header"
		  admin.page.index.add :node, "index_view_posted_time_user", :after => "title_column"
    end

    tab "Content" do
    	add_item("Comments", "/admin/comments")
    end.

    require "fastercsv"

    ActiveRecord::Base.class_eval do
      def self.to_csv(*args)
        find(:all).to_csv(*args)
      end

      def export_columns(format = nil)
        self.class.content_columns.map(&:name) - ['created_at', 'updated_at']
      end

      def to_row(format = nil)
        export_columns(format).map { |c| self.send(c) }
      end
    end

    Array.class_eval do
      def to_csv(options = {})
        return "" if first.nil?
        if all? { |e| e.respond_to?(:to_row) }
          header_row = first.export_columns(options[:format]).to_csv
          content_rows = map { |e| e.to_row(options[:format]) }.map(&:to_csv)
          ([header_row] + content_rows).join
        else
          FasterCSV.generate_line(self, options)
        end
      end
    end

    Admin::PagesController.class_eval do
      before_filter :filter_other_page, :only => [:edit]
      def index
        if current_user.bloger
          @homepage = Page.find_by_blog_directory(1)
        else
          @homepage = Page.find_by_parent_id(nil)
        end
        response_for :plural
      end

      private
        def filter_other_page
          if current_user.bloger && Page.find_by_id(params[:id]).created_by_id != current_user.id
            redirect_to admin_pages_path
            flash[:notice] = t 'You do not have permission to access, the request is denied'
          end
        end
    end

    Admin::NodeHelper.class_eval do
      def render_node(page, locals = {})
        if current_user.bloger && page.created_by_id != current_user.id && page.id != Page.find_by_blog_directory(1).id
          return
        end
        @current_node = page
        locals.reverse_merge!(:level => 0, :simple => false).merge!(:page => page)
        render :partial => 'node', :locals =>  locals
      end
    end

    Admin::UsersHelper.class_eval do
      def roles(user)
        roles = []
        roles << I18n.t('admin') if user.admin?
        roles << I18n.t('designer') if user.designer?
        roles << I18n.t('bloger') if user.bloger?
        roles.join(', ')
      end
    end

    Page.class_eval do
      # Associations
      acts_as_tree :order => 'virtual DESC, created_at DESC'
    end
  end

  def deactivate
  end

end
