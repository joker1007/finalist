require "finalist/version"
require "set"

module Finalist
  class OverrideFinalMethodError < StandardError
    attr_reader :override_class, :origin_class, :unbound_method, :detect_type

    def initialize(message, klass, origin, meth, detect_type)
      super(message)
      @override_class = klass
      @origin_class = origin
      @unbound_method = meth
      @detect_type = detect_type # for debug
    end
  end

  def self.extended(base)
    super
    base.extend(SyntaxMethods)
    base.singleton_class.extend(SyntaxMethods)
    base.extend(ModuleMethods) if base.instance_of?(Module)
  end

  def self.finalized_methods
    @finalized_methods ||= {}
  end

  module ModuleMethods
    def included(base)
      super

      base.extend(Finalist)

      caller_info = caller_locations(1, 2).last
      event_type =
        if caller_info.label.match?(/block/)
          :b_return
        else
          :end
        end

      tp = TracePoint.new(event_type) do |ev|
        if ev.self == base
          base.ancestors.drop(1).each do |mod|
            Finalist.finalized_methods[mod]&.each do |fmeth_name|
              if meth = base.instance_method(fmeth_name)
                super_method = meth.super_method
                while super_method
                  if Finalist.finalized_methods[super_method.owner]&.member?(super_method.name)
                    tp.disable
                    base.instance_variable_set("@__finalist_tp", nil)
                    raise OverrideFinalMethodError.new("#{super_method} at #{super_method.source_location.join(":")} is overrided\n  by #{meth} at #{meth.source_location.join(":")}", base, super_method.owner, meth, :trace_point)
                  end

                  super_method = super_method.super_method
                end
              end
            end
          end
          tp.disable
        end
      end
      tp.enable
      base.instance_variable_set("@__finalist_tp", tp)
    end

    def extended(base)
      def base.singleton_method_added(symbol)
        super

        meth = singleton_class.instance_method(symbol)
        super_method = meth.super_method
        while super_method
          if Finalist.finalized_methods[super_method.owner]&.member?(super_method.name)
            @__finalist_tp&.disable
            @__finalist_tp = nil
            raise OverrideFinalMethodError.new("#{super_method} at #{super_method.source_location.join(":")} is overrided\n  by #{meth} at #{meth.source_location.join(":")}", singleton_class, super_method.owner, meth, :extended_singleton_method_added)
          end
          super_method = super_method.super_method
        end
      end

      base.singleton_class.ancestors.drop(1).each do |mod|
        Finalist.finalized_methods[mod]&.each do |fmeth_name|
          if meth = base.singleton_class.instance_method(fmeth_name)
            super_method = meth.super_method
            while super_method
              if Finalist.finalized_methods[super_method.owner]&.member?(super_method.name)
                base.instance_variable_get("@__finalist_tp")&.disable
                base.instance_variable_set("@__finalist_tp", nil)

                raise OverrideFinalMethodError.new("#{super_method} at #{super_method.source_location.join(":")} is overrided\n  by #{meth} at #{meth.source_location.join(":")}", base.singleton_class, super_method.owner, meth, :extended)
              end
              super_method = super_method.super_method
            end
          end
        end
      end
    end
  end

  module SyntaxMethods
    def final(symbol)
      method_set = Finalist.finalized_methods[self] ||= Set.new
      method_set.add(symbol)
    end
  end

  def method_added(symbol)
    super

    meth = instance_method(symbol)
    super_method = meth.super_method
    while super_method
      if Finalist.finalized_methods[super_method.owner]&.member?(super_method.name)
        @__finalist_tp&.disable
        @__finalist_tp = nil
        raise OverrideFinalMethodError.new("#{super_method} at #{super_method.source_location.join(":")} is overrided\n  by #{meth} at #{meth.source_location.join(":")}", self, super_method.owner, meth, :method_added)
      end
      super_method = super_method.super_method
    end
  end

  def singleton_method_added(symbol)
    super

    meth = singleton_class.instance_method(symbol)
    super_method = meth.super_method
    while super_method
      if Finalist.finalized_methods[super_method.owner]&.member?(super_method.name)
        @__finalist_tp&.disable
        @__finalist_tp = nil
        raise OverrideFinalMethodError.new("#{super_method} at #{super_method.source_location.join(":")} is overrided\n  by #{meth} at #{meth.source_location.join(":")}", self, super_method.owner, meth, :singleton_method_added)
      end
      super_method = super_method.super_method
    end
  end
end
