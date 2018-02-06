RSpec.describe Finalist do
  context "if override not finalized method" do
    it "raise nothing" do
      expect do
        class B1
          extend Finalist

          final def foo
          end
        end

        class B2 < B1
          def bar
          end
        end
      end.not_to raise_error
    end
  end

  context "if override finalized method" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        class A1
          extend Finalist

          final def foo
          end
        end

        class A2 < A1
          def foo
          end
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:method_added)
      expect(ex.override_class).to eq(A2)
      expect(ex.unbound_method.name).to eq(:foo)

      ex = nil
      begin
        Class.new(A1) do
          def foo
          end
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:method_added)
      expect(ex.override_class).not_to eq(A2)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "if override finalized method by another module" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        class O1
          extend Finalist

          final def foo
          end
        end

        module O3
          def foo
          end
        end

        class O2 < O1
          include O3
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:include)
      expect(ex.override_class).to eq(O3)
      expect(ex.unbound_method.name).to eq(:foo)

      ex = nil
      begin
        c = Class.new(O1)
        c.include(O3)
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:include)
      expect(ex.override_class).to eq(O3)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "if override finalized singleton method by another module that is ActiveSupport::Concern style" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        class P1
          extend Finalist

          final_singleton_method def self.foo
          end
        end

        module P3
          def self.included(base)
            super
            base.extend(ClassMethods)
          end

          module ClassMethods
            def foo
            end
          end
        end

        class P2 < P1
          include P3
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:extend)
      expect(ex.override_class).to eq(P3::ClassMethods)
      expect(ex.unbound_method.name).to eq(:foo)

      ex = nil
      begin
        c = Class.new(P1)
        c.include(P3)
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:extend)
      expect(ex.override_class).to eq(P3::ClassMethods)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "if override finalized singleton method by another module (extend)" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        class Q1
          extend Finalist

          final_singleton_method def self.foo
          end
        end

        module Q3
          def foo
          end
        end

        class Q2 < Q1
          extend Q3
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:extend)
      expect(ex.override_class).to eq(Q3)
      expect(ex.unbound_method.name).to eq(:foo)

      ex = nil
      begin
        c = Class.new(Q1)
        c.extend(Q3)
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:extend)
      expect(ex.override_class).to eq(Q3)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "overrided by grandson" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        class C1
          extend Finalist

          final def foo
          end
        end

        class C2 < C1
          def bar
          end
        end

        class C3 < C2
          def foo
          end
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:method_added)
      expect(ex.override_class).to eq(C3)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "if override finalized method (module method)" do
    it "raise Finalist::OverrideFinalMethodError" do
      ex = nil
      begin
        module D1
          extend Finalist

          final def foo
          end
        end

        class D2
          include D1

          def foo
          end
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:method_added)
      expect(ex.override_class).to eq(D2)
      expect(ex.unbound_method.name).to eq(:foo)

      ex = nil
      begin
        Class.new do
          include D1

          def foo
          end
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:method_added)
      expect(ex.override_class).not_to eq(D2)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "overrided by grandson (module method)" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        module E1
          extend Finalist

          final def foo
          end
        end

        module E2
          include E1
        end

        module E3
          include E2

          def foo
          end
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:method_added)
      expect(ex.override_class).to eq(E3)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "override method before method added" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        module F1
          extend Finalist

          final def foo
          end
        end

        class F2
          def foo
          end

          include F1
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:included)
      expect(ex.override_class).to eq(F2)
      expect(ex.unbound_method.name).to eq(:foo)

      ex = nil
      begin
        Class.new do
          def foo
          end

          include F1
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:included)
      expect(ex.override_class).not_to eq(F2)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "override method and open class and method added" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        module G1
          extend Finalist

          final def foo
          end
        end

        class G2
          def foo
          end
        end

        class G2
          include G1
        end

      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:included)
      expect(ex.override_class).to eq(G2)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "override singleton method" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        module H1
          extend Finalist

          final def foo
          end
        end

        a = "str"
        a.extend(H1)
        def a.foo
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:extended_singleton_method_added)
      expect(ex.override_class).to be_a(Class)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "override singleton method before extended" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        module I1
          extend Finalist

          final def foo
          end
        end

        a = "str"
        def a.foo
        end
        a.extend(I1)
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:extended)
      expect(ex.override_class).to be_a(Class)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "if override finalized class method" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        class J1
          extend Finalist

          class << self
            final def foo
            end
          end
        end

        class J2 < J1
          class << self
            def foo
            end
          end
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:singleton_method_added)
      expect(ex.override_class).to eq(J2.singleton_class)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "if override finalized class method after extend module" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        module K1
          extend Finalist

          final def foo
          end
        end

        class K2
          extend K1

          class << self
            def foo
            end
          end
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:extended_singleton_method_added)
      expect(ex.override_class).to eq(K2.singleton_class)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "if override finalized class method before extend module" do
    it "raise Finalist::OverrideFinalMethodError", aggregate_failures: true do
      ex = nil
      begin
        module L1
          extend Finalist

          final def foo
          end
        end

        class L2
          class << self
            def foo
            end
          end

          extend L1
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:extended)
      expect(ex.override_class).to eq(L2.singleton_class)
      expect(ex.unbound_method.name).to eq(:foo)

      ex = nil
      begin
        Class.new do
          self.singleton_class.class_eval do
            def foo
            end
          end

          extend L1
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(ex).not_to be_nil
      expect(ex.detect_type).to eq(:extended)
      expect(ex.override_class).not_to eq(L2.singleton_class)
      expect(ex.unbound_method.name).to eq(:foo)
    end
  end

  context "overrided by module prepend" do
    it "does not raise", aggregate_failures: true do
      ex = nil
      begin
        module M1
          extend Finalist

          final def foo
          end
        end

        module M3
          def foo
            "foo"
          end
        end

        class M2
          include M1
          prepend M3
        end
      rescue Finalist::OverrideFinalMethodError => e
        ex = e
      end

      expect(M2.new.foo).to eq("foo")
      expect(ex).to be_nil
    end
  end

  context "Finalist.disable = true" do
    around do |ex|
      Finalist.disable = true
      ex.call
      Finalist.disable = false
    end

    it "does not raise" do
      expect {
        class N1
          extend Finalist

          final def foo
          end
        end

        class N2 < N1
          def foo
          end
        end

        class N3
          extend Finalist

          class << self
            final def foo
            end
          end
        end

        class N4 < N3
          class << self
            def foo
            end
          end
        end
      }.not_to raise_error
    end
  end
end

# class Hoge
#   extend Finalist
# 
#   final def foo
#   end
# end
# 
# module Bar
#   def foo
#   end
# end
# 
# class Foo < Hoge
#   include Bar
# end
