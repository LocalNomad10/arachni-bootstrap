require 'sinatra'
require 'sinatra/contrib'

def default
    "default.html"
end

FILE_TO_PLATFORM = {
    '/boot.ini'        => :windows,
    '/etc/passwd'      => :unix,
    '/WEB-INF/web.xml' => :tomcat
}

OUT = {
    unix:    'root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/sh
',
    windows: '[boot loader]
timeout=30
default=multi(0)disk(0)rdisk(0)partition(1)\WINDOWS
[operating systems]
multi(0)disk(0)rdisk(0)partition(1)\WINDOWS="Microsoft Windows XP Professional" /fastdetect
',
    tomcat: '<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://java.sun.com/xml/ns/javaee" xmlns:web="http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd" xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd" id="WebApp_ID" version="2.5">
  <display-name>VulnerabilityDetectionChallenge</display-name>
  <welcome-file-list>
    <welcome-file>index.html</welcome-file>
    <welcome-file>index.htm</welcome-file>
    <welcome-file>index.jsp</welcome-file>
    <welcome-file>default.html</welcome-file>
    <welcome-file>default.htm</welcome-file>
    <welcome-file>default.jsp</welcome-file>
  </welcome-file-list>

  <!-- Define a Security Constraint on this Application -->
  <security-constraint>
    <web-resource-collection>
     <web-resource-name>Weak authentication - basic</web-resource-name>
     <url-pattern>/passive/session/weak-authentication-basic.jsp</url-pattern>
    </web-resource-collection>
    <auth-constraint>
     <role-name>tomcat</role-name>
     <role-name>role1</role-name>
    </auth-constraint>
  </security-constraint>

  <!-- Define the Login Configuration for this Application -->
  <login-config>
    <auth-method>BASIC</auth-method>
    <realm-name>Application</realm-name>
    <!--realm-name>Weak authentication - basic</realm-name-->
  </login-config>

  <!-- Security roles referenced by this web application -->
  <security-role>
    <description>
      The role that is required to access protected pages
    </description>
     <role-name>tomcat</role-name>
  </security-role>

  <security-role>
    <description>
      The role that is required to access protected pages
    </description>
     <role-name>role1</role-name>
  </security-role>
'
}

def get_variations( system, str )
    return if !str
    str = str.split( "\0" ).first
    str = str.split( "file:/" ).last
    file = File.expand_path( str ).gsub( /\/+/, '/' )

    OUT[FILE_TO_PLATFORM[file]] if system == FILE_TO_PLATFORM[file]
end

OUT.keys.each do |system|
    system_str = system.to_s

    get '/' + system_str do
        <<-EOHTML
            <a href="/#{system_str}/link?input=default">Link</a>
            <a href="/#{system_str}/form">Form</a>
            <a href="/#{system_str}/cookie">Cookie</a>
            <a href="/#{system_str}/header">Header</a>
        EOHTML
    end

    get "/#{system_str}/link" do
        <<-EOHTML
            <a href="/#{system_str}/link/straight?input=#{default}">Link</a>
            <a href="/#{system_str}/link/with_null?input=#{default}">Link</a>
        EOHTML
    end

    get "/#{system_str}/link/straight" do
        return if params['input'].start_with?( default ) || params['input'].include?( "\0" )
        get_variations( system, params['input'] )
    end

    get "/#{system_str}/link/with_null" do
        return if !params['input'].end_with?( "\00.html" )
        get_variations( system, params['input'].split( "\0.html" ).first )
    end

    get "/#{system_str}/form" do
        <<-EOHTML
            <form action="/#{system_str}/form/straight" method='post'>
                <input name='input' value='#{default}' />
            </form>

            <form action="/#{system_str}/form/with_null" method='post'>
                <input name='input' value='#{default}' />
            </form>

        EOHTML
    end

    post "/#{system_str}/form/straight" do
        return if params['input'].start_with?( default ) || params['input'].include?( "\0" )
        get_variations( system, params['input'] )
    end

    post "/#{system_str}/form/with_null" do
        return if !params['input'].end_with?( "\00.html" )
        get_variations( system, params['input'].split( "\0.html" ).first )
    end

    get "/#{system_str}/cookie" do
        <<-HTML
            <a href="/#{system_str}/cookie/straight">Cookie</a>
            <!-- <a href="/#{system_str}/cookie/with_null">Cookie</a> -->
        HTML
    end

    get "/#{system_str}/cookie/straight" do
        cookies['cookie'] ||= default
        return if cookies['cookie'].start_with?( default ) #|| cookies['cookie'].include?( "\0" )

        get_variations( system, cookies['cookie'] )
    end

    #get "/#{system_str}/cookie/with_null" do
    #    cookies['cookie1'] ||= default
    #    return if !cookies['cookie1'].end_with?( "\00.html" )
    #
    #    p cookies['cookie1']
    #    get_variations( system, cookies['cookie1'] )
    #end

    get "/#{system_str}/header" do
        <<-EOHTML
            <a href="/#{system_str}/header/straight">Header</a>
            <a href="/#{system_str}/header/with_null">Header</a>
        EOHTML
    end

    get "/#{system_str}/header/straight" do
        default = 'arachni_user'
        return if env['HTTP_USER_AGENT'].start_with?( default ) || env['HTTP_USER_AGENT'].include?( "\0" )

        get_variations( system, env['HTTP_USER_AGENT'] )
    end

    get "/#{system_str}/header/with_null" do
        default = 'arachni_user'
        return if !env['HTTP_USER_AGENT'].end_with?( "\00.html" )

        get_variations( system, env['HTTP_USER_AGENT'] )
    end

end
