require 'test/unit'
require "#{File.dirname(__FILE__)}/../lib/minevent/buffer"

class BufferTest < Test::Unit::TestCase
  def test_with_one_entry
    buffer = Minevent::Buffer.new
    buffer << "foo\n"
    
    assert_equal(["foo"], buffer.entries)
  end
  
  def test_with_two_entries
    buffer = Minevent::Buffer.new
    buffer << "foo\n"
    buffer << "bar\n"
    
    assert_equal(["foo", "bar"], buffer.entries)
  end
  
  def test_with_partial_entry
    buffer = Minevent::Buffer.new
    buffer << "foo\n"
    buffer << "ba"
    
    assert_equal(["foo"], buffer.entries)
  end
  
  def test_complete_partial_entry
    buffer = Minevent::Buffer.new
    buffer << "foo\n"
    buffer << "ba"
    buffer << "r\n"
    
    assert_equal(["foo", "bar"], buffer.entries)
  end
  
  def test_end
    buffer = Minevent::Buffer.new
    buffer << "foo\n"
    buffer << "bar"
    buffer.end
    
    assert_equal(["foo", "bar"], buffer.entries)
  end
  
  def test_end_on_empty
    buffer = Minevent::Buffer.new
    buffer.end
    
    assert_equal([], buffer.entries)
  end
  
  def test_end_on_ended
    buffer = Minevent::Buffer.new
    buffer << "foo\n"
    buffer.end
    
    assert_equal(["foo"], buffer.entries)
  end
  
  def test_network_separator
    buffer = Minevent::Buffer.new("", "\r\n")
    buffer << "foo\r\n"
    buffer << "bar"
    buffer.end
    
    assert_equal(["foo", "bar"], buffer.entries)
  end
  
  def test_each
    buffer = Minevent::Buffer.new
    buffer << "foo\n"
    buffer << "bar\n"
    
    results = []
    buffer.each {|element| results.push(element)}
    
    assert_equal(["foo", "bar"], results)
  end
  
  def test_each_without_block
    buffer = Minevent::Buffer.new
    buffer << "foo\n"
    buffer << "bar\n"
    
    # ensure we match the current version of ruby's behaviour
    # LocalJumpError for <= 1.8.6, Enumerable::Enumerator for >= 1.8.7
    begin
      [1].each
      supports_each_without_block = true
    rescue LocalJumpError
      supports_each_without_block = false
    end
    
    if supports_each_without_block
      result = buffer.each
      assert_instance_of(Enumerable::Enumerator, result)
      assert_equal("foo", result.next)
      assert_equal("bar", result.next)
      assert_raise(StopIteration) {result.next}
    else
      assert_raise(LocalJumpError) {buffer.each}
      # 1.8.6 crazily returns an empty array with #each on an empty array
      empty_buffer = Minevent::Buffer.new
      assert_equal([], buffer.each)
    end
  end
  
  def test_each_return_value_with_block
    buffer = Minevent::Buffer.new
    buffer << "foo\n"
    buffer << "bar\n"
    
    assert_equal(["foo", "bar"], buffer.each {})
  end
end