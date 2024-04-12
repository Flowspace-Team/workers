#
# SortedSet implements a Set that guarantees that its elements are
# yielded in sorted order (according to the return values of their
# #<=> methods) when iterating over them.
#
# All elements that are added to a SortedSet must respond to the <=>
# method for comparison.
#
# Also, all elements must be <em>mutually comparable</em>: <tt>el1 <=>
# el2</tt> must not return <tt>nil</tt> for any elements <tt>el1</tt>
# and <tt>el2</tt>, else an ArgumentError will be raised when
# iterating over the SortedSet.
#
# == Example
#
#   require "set"
#
#   set = SortedSet.new([2, 1, 5, 6, 4, 5, 3, 3, 3])
#   ary = []
#
#   set.each do |obj|
#     ary << obj
#   end
#
#   p ary # => [1, 2, 3, 4, 5, 6]
#
#   set2 = SortedSet.new([1, 2, "3"])
#   set2.each { |obj| } # => raises ArgumentError: comparison of Fixnum with String failed
#
module Workers
  class SortedSet < Set
    @@setup = false
    @@mutex = Mutex.new

    class << self
      def [](*ary)        # :nodoc:
        new(ary)
      end

      def setup   # :nodoc:
        @@setup and return

        @@mutex.synchronize do
          # a hack to shut up warning
          alias_method :old_init, :initialize

          def initialize(*args)
            @keys = nil
            super
          end

          def clear
            @keys = nil
            super
          end

          def replace(enum)
            @keys = nil
            super
          end

          def add(o)
            o.respond_to?(:<=>) or raise ArgumentError, "value must respond to <=>"
            @keys = nil
            super
          end
          alias << add

          def delete(o)
            @keys = nil
            @hash.delete(o)
            self
          end

          def delete_if
            block_given? or return enum_for(__method__) { size }
            n = @hash.size
            super
            @keys = nil if @hash.size != n
            self
          end

          def keep_if
            block_given? or return enum_for(__method__) { size }
            n = @hash.size
            super
            @keys = nil if @hash.size != n
            self
          end

          def merge(enum)
            @keys = nil
            super
          end

          def each(&block)
            block or return enum_for(__method__) { size }
            to_a.each(&block)
            self
          end

          def to_a
            (@keys = @hash.keys).sort! unless @keys
            @keys.dup
          end

          def freeze
            to_a
            super
          end

          def rehash
            @keys = nil
            super
          end

          # a hack to shut up warning
          remove_method :old_init

          @@setup = true
        end
      end
    end

    def initialize(*args, &block) # :nodoc:
      SortedSet.setup
      @keys = nil
      super
    end
  end
end
