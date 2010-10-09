def path_to(page_name)
  case page_name
  
  when /the homepage/i
    root_path
  
  when /login/i
    login_path
<<<<<<< HEAD
  # Add more page name => path mappings here
  
=======
    
  when /comments/i
    admin_comments_path
  # Add more page name => path mappings here
>>>>>>> b701a0b8eeeeaee4206c1360b7e1cd87645c7da3
  else
    raise "Can't find mapping from \"#{page_name}\" to a path."
  end
end