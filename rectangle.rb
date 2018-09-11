class EggDrive
  class Rectangle
    attr_reader :x, :y, :width, :height

    def initialize(width, height, x=0, y=0)
      @width = width
      @height = height
      @x = x
      @y = y
    end
  end
end