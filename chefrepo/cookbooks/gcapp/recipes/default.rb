service "nginx" do
    action :nothing
end

package "nginx" do
    action :install
    notifies :restart, 'service[nginx]', :delayed
    notifies :enable, 'service[nginx]', :delayed
end

file "/var/www/html/index.nginx-debian.html" do
    action :delete
end

file '/var/www/html/health' do
    content 'Healthy'
    mode '0644'
    owner 'www-data'
    group 'www-data'
end

template "/var/www/html/index.html" do
    source 'index.html.erb'
    mode '0644'
    owner 'www-data'
    group 'www-data'
end

# add http basic auth file to block access to whole site
cookbook_file '/etc/nginx/conf.d/.htpasswd' do
    source '.htpasswd'
    owner 'www-data'
    group 'www-data'
    mode '0440'
    action :create
    notifies :reload, 'service[nginx]', :delayed
end

template "/etc/nginx/sites-available/default" do
    source 'nginx-default.erb'
    mode '0644'
    owner 'root'
    group 'root'
    notifies :reload, 'service[nginx]', :delayed
end

