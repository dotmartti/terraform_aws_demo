service "nginx" do
    action :nothing
end

package "nginx" do
    action :install
    notifies :restart, 'service[nginx]', :delayed
    notifies :enable, 'service[nginx]', :delayed
end