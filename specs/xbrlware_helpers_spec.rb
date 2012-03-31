# string_helpers_spec.rb

require 'spec_helper'

describe Xbrlware::Context::Period do
  describe ".days" do
    context "when a date range" do
      let(:value) { {"start_date"=>Date.parse("2011-01-01"), "end_date"=>Date.parse("2011-03-31")} }
      subject { Xbrlware::Context::Period.new(value).days }

      it { should be_a Fixnum }
      it { should == Xbrlware::DateUtil.days_between(value["end_date"], value["start_date"]) }
    end
  end
  describe ".plus_n_months" do
    context "when an instantaneous date" do
      let(:old_value) { Date.parse("2010-12-31") }
      let(:old) { old = Xbrlware::Context::Period.new(old_value) }

      subject { old.plus_n_months(3) }

      it { should be_a Xbrlware::Context::Period }
      its(:to_pretty_s) { should == "2011-03-28" }
    end
    context "when a date range" do
      let(:old_value) { {"start_date"=>Date.parse("2011-01-01"), "end_date"=>Date.parse("2011-03-31")} }
      let(:old) { old = Xbrlware::Context::Period.new(old_value) }

      subject { old.plus_n_months(3) }

      it { should be_a Xbrlware::Context::Period }
      its(:to_pretty_s) { should == "2011-04-01 to 2011-06-30" }
    end
  end
end

describe Xbrlware::Context do

  describe "write_constructor" do
    context "when the period is nil" do
      before(:all) do
        file_name = "/tmp/xbrlware-extras-context1.rb"
        item_name = "@item_context"
        file = File.open(file_name, "w")
        @orig_item = Xbrlware::Factory.Context()
        @orig_item.write_constructor(file, item_name)
        file.close
  
        eval(File.read(file_name))
  
        @loaded_item = eval(item_name)
      end
  
      it "writes itself to a file, and when reloaded, has the same period" do
        @loaded_item.period.value.should == @orig_item.period.value
      end
    end

    context "when the period is an instant" do
      before(:all) do
        file_name = "/tmp/xbrlware-extras-context2.rb"
        item_name = "@item_context"
        file = File.open(file_name, "w")
        @orig_item = Xbrlware::Factory.Context(:period => Date.parse("2010-01-01"))
        @orig_item.write_constructor(file, item_name)
        file.close
  
        eval(File.read(file_name))
  
        @loaded_item = eval(item_name)
      end
  
      it "writes itself to a file, and when reloaded, has the same period" do
        @loaded_item.period.to_pretty_s.should == @orig_item.period.to_pretty_s
      end
    end

    context "when the period is a duration" do
      before(:all) do
        file_name = "/tmp/xbrlware-extras-context3.rb"
        item_name = "@item_context"
        file = File.open(file_name, "w")
        @orig_item = Xbrlware::Factory.Context(:period => {"start_date" => Date.parse("2010-01-01"),
                                                              "end_date"   => Date.parse("2011-01-01")})
        @orig_item.write_constructor(file, item_name)
        file.close
  
        eval(File.read(file_name))
  
        @loaded_item = eval(item_name)
      end
  
      it "writes itself to a file, and when reloaded, has the same period" do
        @loaded_item.period.to_pretty_s.should == @orig_item.period.to_pretty_s
      end
    end
  end

end

describe Xbrlware::Linkbase::CalculationLinkbase::Calculation do
  describe ".top_level_arcs" do
    before(:all) do
      @calc = Xbrlware::Factory.Calculation(:title=>"Statement of Something or Other") 
      @calc.arcs << Xbrlware::Factory.CalculationArc(:label=>"A0")
	  @calc.arcs.first.items = []
      @calc.arcs.first.items << Xbrlware::Factory.Item(:name=>"A0.I0")

      @calc.arcs << Xbrlware::Factory.CalculationArc(:label=>"B0")
	  @calc.arcs.last.children = []
      @calc.arcs.last.children << Xbrlware::Factory.CalculationArc(:label=>"B0.B1")

	  @calc.arcs.last.children.first.items = []
      @calc.arcs.last.children.first.items << Xbrlware::Factory.Item(:name=>"B0.B1.I0")

      @calc.arcs.last.children << @calc.arcs.first # B0 contains A0
    end
    subject { @calc.top_level_arcs }
    it { should have(1).items }
    its(:first) { should be @calc.arcs.last }
  end

  describe ".is_disclosure?" do
    context "when its title begins with 'Disclosure'" do
      let(:calc) { Xbrlware::Factory.Calculation(:title=>"Disclosure of Something or Other") }
      subject { calc.is_disclosure? }
      it { should == true }
    end
    context "when its title does not begin with 'Disclosure'" do
      let(:calc) { Xbrlware::Factory.Calculation(:title=>"Statement of Something or Other") }
      subject { calc.is_disclosure? }
      it { should == false }
    end
  end
end

describe Xbrlware::Linkbase::CalculationLinkbase::Calculation::CalculationArc do
  describe ".write_constructor" do
    before(:all) do
      calc = Xbrlware::Factory.Calculation(:title=>"Statement of Something or Other") 
      calc.arcs << Xbrlware::Factory.CalculationArc(:label=>"B0")
	  calc.arcs.last.items = []
	  calc.arcs.last.children = []
      calc.arcs.last.children << Xbrlware::Factory.CalculationArc(:label=>"B0.B1", :items=>[])
	  calc.arcs.last.children.first.items = []
      calc.arcs.last.children.first.items << Xbrlware::Factory.Item(:name=>"B0.B1.I0")

      @orig_item = calc.arcs.first

      file_name = "/tmp/xbrlware-extras-calc-arc.rb"
      item_name = "@item"
      file = File.open(file_name, "w")
      @orig_item.write_constructor(file, item_name)
      file.close

      eval(File.read(file_name))
      @loaded_item = eval(item_name)
    end

    it "writes itself to a file, and when reloaded, has the same item_id" do
      @loaded_item.item_id.should == @orig_item.item_id
    end
    it "writes itself to a file, and when reloaded, has the same label" do
      @loaded_item.label.should == @orig_item.label
    end
    it "writes itself to a file, and when reloaded, has the same number of children" do
      @loaded_item.children.length.should == @orig_item.children.length
    end
    it "writes itself to a file, and when reloaded, has the same number of items" do
      @loaded_item.items.length.should == @orig_item.items.length
    end
  end

  describe ".contains_arc?" do
    before(:each) do
      @calc = Xbrlware::Factory.Calculation(:title=>"Statement of Something or Other") 
      @calc.arcs << Xbrlware::Factory.CalculationArc(:label=>"A0")
	  @calc.arcs.first.items = []
      @calc.arcs.first.items << Xbrlware::Factory.Item(:name=>"A0.I0")

      @calc.arcs << Xbrlware::Factory.CalculationArc(:label=>"B0")
	  @calc.arcs.last.children = []
      @calc.arcs.last.children << Xbrlware::Factory.CalculationArc(:label=>"B0.B1")

	  @calc.arcs.last.children.first.items = []
      @calc.arcs.last.children.first.items << Xbrlware::Factory.Item(:name=>"B0.B1.I0")
    end
    context "when the first arc does not contain the second arc" do
      subject { @calc.arcs.first.contains_arc?(@calc.arcs.last) }
      it { should == false }
    end
    context "when the first arc contains the second arc" do
      before(:each) do
        @calc.arcs.last.children << @calc.arcs.first # B0 contains A0
      end

      subject { @calc.arcs.last.contains_arc?(@calc.arcs.first) }
      it { should == true }
    end
    context "when the first arc contains a second arc that contains the third arc" do
      before(:each) do
        @calc.arcs.last.children << Xbrlware::Factory.CalculationArc(:label=>"B0.B2")
        @calc.arcs.last.children.last.children << @calc.arcs.first # B0.B2 contains A0
      end

      subject { @calc.arcs.last.contains_arc?(@calc.arcs.first) }
      it { should == true }
    end
  end

end

