module Bowtie

	module Helpers

		def app_name
			defined?(APP_NAME) ? APP_NAME : ENV['APP_NAME'] || "Bowtie::#{adapter_name}"
		end

		def adapter_name
			defined?(DataMapper) ? "DataMapper" : "MongoMapper"
		end

		def action_name
			model.pluralize
		end

		def base_path
			env['SCRIPT_NAME']
		end

		# requests, redirects

		def deliver_file
			path = File.expand_path(File.dirname(__FILE__)) + "/public#{@env['PATH_INFO']}"
			return false unless File.exist?(path)
			content_type(Rack::Mime::MIME_TYPES[File.extname(path)], :charset => 'utf-8')
			File.read(path)
		end

		def redirect(uri, *args)
			super base_path + uri.downcase, *args
		end

		def referer
			URI.parse(@env['HTTP_REFERER']).path.sub("#{base_path}", '')
		end

		def clean_params
			@env['rack.request.query_hash'].delete_if{|a,b| %w(model page notice error q).include?(a) }
		end

		# models, resources

		def mappings
			@mappings ||= get_mappings
		end

		def get_mappings
			mappings = {}
			Bowtie.models.collect{|m| mappings[m.linkable] = m }
			mappings
		end

		def get_model_class(mod = params[:model])
			m = mappings[mod] or halt(404, "Model not found.")
			m.extend(ClassMethods) unless m.respond_to?(:model_associations)
			m
		end

		def model
			@model ||= get_model_class
		end

		def resource
			Bowtie.get_one(model, params[:id]) or halt(404, 'Resource not found!')
		end

		# views, paths

		def partial(name, *args)
			erb(name, {:layout => false}, *args)
		end

		def model_path(m = model)
			string = m.name ||= m
			linkable_path(string.to_s.pluralize.downcase)
		end

		def linkable_path(linkable)
			base_path + '/' + linkable
		end

		def url_for(resource)
			model_path(resource.class) + '/' + resource.id.to_s
		end

		def link_to(string, resource)
			uri = resource.nil? ? "#" : url_for(resource)
			"<a href='#{uri}'>#{string}</a>"
		end

		def truncate(str, length)
			str.to_s.length > length ? str.to_s[0..length] + '&hellip;' : str.to_s
		end

		def render_assoc_header(rel_name, assoc)
			"<th title='#{assoc.class.name.to_s[/.*::(.*)$/, 1]}' class='rel-col #{rel_name}-col'>#{rel_name.to_s.titleize}</th>"
		end

		def render_assoc_row(r, rel_name, assoc)
			html = "<td class='rel-col #{rel_name.to_s}-col'>"
			html += "<a href='#{model_path}/#{r.id}/#{rel_name.to_s}'>"
			if Bowtie.has_one_association?(assoc) || Bowtie.belongs_to_association?(assoc)
				html += (r.send(rel_name).nil? ? 'nil' : "View #{rel_name.to_s}")
			else
				html += Bowtie.get_count(r, rel_name).to_s
			end
			html += "</a></td>"
		end

	end

end
