# Author::    Maurizio Casimirri (mailto:maurizio.cas@gmail.com)
# Copyright:: Copyright (c) 2012 Maurizio Casimirri
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


module MetaTagsHelpers

  

  module ActionViewExtension
    
    def meta_tags(opts = {})

      default   = {
        :charset => "utf-8", 
        :"X-UA-Compatible" => "IE=edge,chrome=1", 
        :viewport => "width=device-width"
        :og => { 
          :url => "#{request.url}", 
          :type => "article",
          :title => opts[:title],
          :description => opts[:description],
          :image => (opts[:og] && opts[:og][:image])
        },
        :"csrf-param" => request_forgery_protection_token,
        :"csrf-token" => form_authenticity_token
      }
      
      meta_hash = default.deep_merge(opts).deep_merge(@_meta_tags_hash || {})
        
      # separates namespaced keys
      namespaces = meta_hash.select { |k,v| v.is_a?(Hash) }
        
      # delete nil/false/namespaced keys
      meta_hash.delete_if { |k,v| v.blank? || v == false || v.is_a?(Hash)}
        
      namespaces.each { |ns, namespaced|
        namespaced.delete_if { |k,v|
          v.blank? || v == false || v.is_a?(Hash)
        }
        namespaced.each {|k,v|
          meta_hash[:"#{ns}:#{k}"] = v 
        }
      }
        
      html = ""
      html << "<title>#{h(meta_hash.delete(:title)) }</title>\n"
      meta_hash.each {|k,v|
        if k.to_s =~ /[a-zA-Z_][-a-zA-Z0-9_.]\:/
          html << "<meta property=\"#{h(k)}\" content=\"#{h(v)}\" />\n"  
        else
          html << "<meta name=\"#{h(k)}\" content=\"#{h(v)}\" />\n"  
        end
      }
      html.html_safe
    end
    
  end
  
  module ActionControllerExtension
    extend ActiveSupport::Concern
    included do
      helper_method :set_meta, :meta_title, :meta_description, :meta_image, :meta_type
    end
    
    def _meta_tags_hash
      @_meta_tags_hash ||= {}
    end
  
    def set_meta(options)
      _meta_tags_hash.deep_merge(options)
    end
  
    def meta_title(val)
      set_meta(:title => val)
    end
      
    def meta_description(val)
      set_meta(:description => val)
    end
      
    def meta_image(val)
      set_meta(:og => { :image => :val })
    end

    def meta_type(val)
      set_meta(:og => { :type  => :val })      
    end
    
  end
end
ActionController::Base.send :include, MetaTagsHelpers::ActionControllerExtension
ActionView::Base.send :include, MetaTagsHelpers::ActionViewExtension