require "finalist/version"
require "set"

using Module.new {
  refine Object do
    def verify_final_method(meth, detect_type)
      super_method = meth.super_method
      while super_method
        if Finalist.finalized_methods[super_method.owner]&.member?(super_method.name)
          raise Finalist::OverrideFinalMethodError.new("#{super_method.owner}##{super_method.name} at #{super_method.source_location.join(":")} is overrided\n  by #{meth.owner}##{meth.name} at #{meth.source_location.join(":")}", meth.owner, super_method.owner, meth, detect_type)
        end
        super_method = super_method.super_method
      end
    end
  end
}

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

  @disable = false

  def self.disable=(v)
    @disable = v
  end

  def self.disabled?
    @disable
  end

  def self.enabled?
    !disabled?
  end

  def self.extended(base)
    super
    base.extend(SyntaxMethods)
    base.singleton_class.extend(SyntaxMethods)
    if enabled?
      base.extend(ModuleMethods) if base.is_a?(Module)
    end
  end

  def self.finalized_methods
    @finalized_methods ||= {}
  end

  private

  def method_added(symbol)
    super

    return if Finalist.disabled?

    verify_final_method(instance_method(symbol), :method_added)
  end

  def singleton_method_added(symbol)
    super

    return if Finalist.disabled?

    verify_final_method(singleton_class.instance_method(symbol), :singleton_method_added)
  end

  module ModuleMethods
    private

    def included(base)
      super

      return if Finalist.disabled?

      base.extend(Finalist)

      base.ancestors.drop(1).each do |mod|
        Finalist.finalized_methods[mod]&.each do |final_method_name|
          meth =
            begin
              meth = base.instance_method(final_method_name)
            rescue NoMethodError
              nil
            end

          verify_final_method(meth, :included) if meth
        end
      end
    end

    def extended(base)
      def base.singleton_method_added(symbol)
        super

        return if Finalist.disabled?

        meth =
          begin
            singleton_class.instance_method(symbol)
          rescue NoMethodError
            nil
          end

        verify_final_method(meth, :extended_singleton_method_added) if meth
      end

      base.singleton_class.ancestors.drop(1).each do |mod|
        Finalist.finalized_methods[mod]&.each do |final_method_name|
          meth =
            begin
              base.singleton_class.instance_method(final_method_name)
            rescue NoMethodError
              nil
            end

          verify_final_method(meth, :extended) if meth
        end
      end
    end
  end

  module SyntaxMethods
    private

    def final(symbol)
      method_set = Finalist.finalized_methods[self] ||= Set.new
      instance_method(symbol)
      method_set.add(symbol)
      symbol
    end

    def final_singleton_method(symbol)
      method_set = Finalist.finalized_methods[self.singleton_class] ||= Set.new
      singleton_class.instance_method(symbol)
      method_set.add(symbol)
      symbol
    end
  end
end
