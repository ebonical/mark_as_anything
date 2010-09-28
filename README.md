Mark As Anything
================

A simple way of marking objects with things like 'read' or 'starred'.

Installation
------------

Install it as a plugin. Then run `./script/generate mark_as_anything` to create a migration.

Example
-------
    
    # models
    class User < ActiveRecord::Base
      markable_actor
    end
    
    class Message < ActiveRecord::Base
      markable_with :read
    end
    
    # usage
    @message.is_read_by?(@user) #=> false
    @message.mark_as_read_by(@user)
    @message.is_read_by?(@user) #=> true
    
    Message.read_by(@user) #=> fetches messages read by user
    
In the example above the markable object will receive these methods:

* `is_read_by?(actor)`
* `mark_as_read_by(actor)`
* `unmark_as_read_by(actor)`
* `unmark_as_read_by_all`

The actor object will have these methods added:

* `has_read?(object)`
    
Obvious Limitations
-------------------
* Currently only a User model can become `markable_actor` (TODO)
* Inverse selection of objects needs to be done yourself. i.e. Getting all of the *un*read messages in the example above would
  require something like `unread_messages = Message.all - Message.read_by(@user)`. Everybody's situation is different so it's
  difficult to account for all cases.

Copyright (c) 2010 Ebony Charlton, released under the MIT license SyntaxError
