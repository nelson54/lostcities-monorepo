FROM docker.io/openresty/openresty:alpine-fat	

RUN /usr/local/openresty/luajit/bin/luarocks install knyar/nginx-lua-prometheus

RUN /usr/local/openresty/luajit/bin/luarocks list

RUN ls /usr/local/openresty/luajit/lib/luarocks/rocks-5.1/
RUN ls /usr/local/openresty/luajit/lib/luarocks/rocks-5.1/nginx-lua-prometheus
