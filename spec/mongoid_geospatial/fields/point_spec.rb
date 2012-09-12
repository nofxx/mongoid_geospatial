require "spec_helper"

describe Mongoid::Geospatial::Point do

  it "should not inferfer with mongoid" do
    Bar.create!(name: "Moe's")
    Bar.count.should eql(1)
  end

  describe "queryable" do

    before do
      Bar.create_indexes
    end

    describe ":near :near_sphere" do

      let!(:berlin) do
        Bar.create(:name => :berlin, :location => [ 52.30, 13.25 ])
      end

      let!(:prague) do
        Bar.create(:name => :prague, :location => [ 50.5, 14.26 ])
      end

      let!(:paris) do
        Bar.create(:name => :paris, :location => [ 48.48, 2.20 ])
      end

      let!(:jim) do
        Person.new(:location => [ 41.23, 2.9 ])
      end

      it "returns the documents sorted closest to furthest" do
        Bar.where(:location.near => jim.location).should == [ paris, prague, berlin ]
      end

      it "returns the documents sorted closest to furthest sphere" do
        person = Person.new(:location => [ 41.23, 2.9 ])
        Bar.where(:location.near_sphere => jim.location).should == [ paris, prague, berlin ]
      end

      it "returns the documents sorted closest to furthest with max" do
        Bar.near(location: jim.location).max_distance(location: 10).to_a.should == [ paris ] #, prague, berlin ]
      end

    end

    describe ":within_circle :within_spherical_circle" do
      let!(:mile1) do
        Bar.create(:name => 'mile1', :location => [-73.997345, 40.759382])
      end

      let!(:mile3) do
        Bar.create(:name => 'mile3', :location => [-73.927088, 40.752151])
      end

      let!(:mile7) do
        Bar.create(:name => 'mile7', :location => [-74.0954913, 40.7161472])
      end

      let!(:mile9) do
        Bar.create(:name => 'mile9', :location => [-74.0604951, 40.9178011])
      end

      let!(:elvis) do
        Person.new(:location => [-73.98, 40.75])
      end

      it "returns the documents within a center_circle" do
        Bar.where(:location.within_circle => [elvis.location, 250.0/Mongoid::Geospatial::EARTH_RADIUS_KM]).to_a.should == [ mile1 ]
      end

      it "returns the documents within a center_circle" do
        Bar.where(:location.within_circle => [elvis.location, 500.0/Mongoid::Geospatial::EARTH_RADIUS_KM]).to_a.should include(mile3)
      end

      it "returns the documents within a center_sphere" do
        Bar.where(:location.within_spherical_circle => [elvis.location, 0.0005]).to_a.should == [ mile1 ]
      end

      it "returns the documents within a center_sphere" do
        Bar.where(:location.within_spherical_circle => [elvis.location, 0.5]).to_a.should include(mile9)
      end
    end

  end

  describe "(de)mongoize" do

    it "should mongoize array" do
      bar = Bar.new(location: [10, -9])
      bar.location.class.should eql(Mongoid::Geospatial::Point)
      bar.location.x.should be_within(0.1).of(10)
      bar.location.y.should be_within(0.1).of(-9)
    end

    it "should mongoize hash" do
      geom = Bar.new(location: {x: 10, y: -9}).location
      geom.class.should eql(Mongoid::Geospatial::Point)
      geom.x.should be_within(0.1).of(10)
      geom.y.should be_within(0.1).of(-9)
    end


    describe "methods" do

      it "should have a .to_a" do
        bar = Bar.create!(location: [3,2])
        bar.location.to_a[0..1].should == [3.0, 2.0]
      end

      it "should have an array [] accessor" do
        bar = Bar.create!(location: [3,2])
        bar.location[0].should == 3.0
      end

      it "should have an ActiveModel symbol accessor" do
        bar = Bar.create!(location: [3,2])
        bar[:location].should == [3,2]
      end

      it "should calculate distance between points" do
        pending
        bar = Bar.create!(location: [5,5])
        bar2 = Bar.create!(location: [15,15])
        bar.location.distance(bar2.location).should be_within(1).of(1561283.8)
      end

      it "should calculate 3d distances by default" do
        pending
        bar = Bar.create! location: [-73.77694444, 40.63861111 ]
        bar2 = Bar.create! location: [-118.40, 33.94] #,:unit=>:mi, :spherical => true)
        bar.location.distance(bar2.location).to_i.should be_within(1).of(2469)
      end

    end

    # should raise
    # geom.to_geo

    describe "with rgeo" do

      before do
        require 'mongoid_geospatial_rgeo'
      end

      it "should mongoize array" do
        geom = Bar.new(location: [10, -9]).location
        geom.class.should eql(Mongoid::Geospatial::Point)
        geom.to_geo.class.should eql(RGeo::Geographic::SphericalPointImpl)
        geom.x.should be_within(0.1).of(10)
        geom.to_geo.y.should be_within(0.1).of(-9)
      end

      it "should mongoize hash" do
        geom = Bar.new(location: {x: 10, y: -9}).location
        geom.class.should eql(Mongoid::Geospatial::Point)
        geom.to_geo.class.should eql(RGeo::Geographic::SphericalPointImpl)
      end

      it "should accept an RGeo object" do
        pending
        point = RGeo::Geographic.spherical_factory.point 1, 2
        bar = Bar.create!(location: point)
        bar.location.x.should be_within(0.1).of(1)
        bar.location.y.should be_within(0.1).of(2)
      end


      describe "instantiated" do

        let(:bar) { Bar.create!(name: 'Vitinho', location: [10,10]) }

        it "should demongoize to rgeo" do
          bar.location.class.should eql(Mongoid::Geospatial::Point)
        end

      end


    end

  end


end
