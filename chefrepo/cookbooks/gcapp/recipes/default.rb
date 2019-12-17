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

template "/var/www/html/index.html" do
    source 'index.html.erb'
    mode '0644'
    owner 'root'
    group 'root'
end