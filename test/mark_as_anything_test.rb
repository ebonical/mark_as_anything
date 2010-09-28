require 'test_helper'

class User < ActiveRecord::Base
  markable_actor
end

class Message < ActiveRecord::Base
  markable_with :read
  
  # A test method to see that the method_missing and respond_to? tests don't hog everything
  def is_bounded_by?(message = 'boom')
    message
  end
end

class MarkAsAnythingTest < ActiveSupport::TestCase
  def setup
    @user = User.create
    @message = Message.create
  end
  
  test "User should be markable actor" do
    assert_equal MarkAsAnything.actor, User
  end
  
  test "Message should have :read marker" do
    assert Message.markable_markers.include?("read")
  end
  
  test "Message should start as unread" do
    assert !@message.is_read_by?(@user)
  end
  
  test "should be markable as read" do
    @message.mark_as_read_by(@user)
    m = Message.find(@message) # full fresh reload
    assert m.is_read_by?(@user)
  end
  
  test "should be unmarkable as read" do
    @message.mark_as_read_by(@user)
    @message.unmark_as_read_by(@user)
    m = Message.find(@message) # full fresh reload
    assert !m.is_read_by?(@user)
  end
  
  test "multiple messages" do
    m2 = Message.create
    @message.mark_as_read_by(@user)
    assert !m2.is_read_by?(@user)
  end
  
  test "remove markers for all users" do
    u2 = User.create
    [@user, u2].each do |user|
      @message.mark_as_read_by(user)
      assert @message.is_read_by?(user)
    end
    @message.unmark_as_read_by_all
    [@user, u2].each do |user|
      assert !@message.is_read_by?(user)
    end
  end
  
  test "unmark all from nothing should not raise error" do
    @message.unmark_as_read_by_all
  end
  
  test "reverse read checking (actor to object)" do
    assert !@user.has_read?(@message)
    @message.mark_as_read_by(@user)
    assert @user.has_read?(@message)
  end
  
  test "'read_by' named scope" do
    5.times { Message.create }
    m1 = Message.first
    m1.mark_as_read_by(@user)
    messages = Message.read_by(@user)
    assert_equal [m1], messages
  end
  
  test "'read_by' named scope with more than 1 user" do
    u2 = User.create
    3.times { Message.create }
    messages = Message.all
    messages.first.mark_as_read_by(@user)
    messages.last.mark_as_read_by(u2)
    assert_equal [messages.last], Message.read_by(u2)
  end
  
  test "object should respond to all methods" do
    [:is_read_by?, :mark_as_read_by, :unmark_as_read_by, :unmark_as_read_by_all].each do |method|
      assert @message.respond_to?(method), "Did not respond to :#{method}"
    end
  end
  
  test "should not respond to a similarly formed method" do
    assert !@message.respond_to?(:is_jumped_by?)
    assert @message.respond_to?(:is_bounded_by?) # The test method
  end
  
  test "similarly formed methods should not be caught by method missing" do
    assert_equal 'boom', @message.is_bounded_by?('boom')
    assert_raise NoMethodError do
      @message.is_somethinged_by?(@user)
    end
  end
  
  # test "actor should respond to all methods" do
  #   [:has_read?].each do |method|
  #     assert @user.respond_to?(method), "Did not respond to :#{method}"
  #   end
  # end
end
