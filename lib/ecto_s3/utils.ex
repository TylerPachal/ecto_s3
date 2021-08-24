defmodule EctoS3.Utils do

  def get_option(key, first_place) do
    first_place[key]
  end
  def get_option(key, first_place, second_place) do
    get_option(key, first_place) || get_option(key, second_place)
  end
  def get_option(key, first_place, second_place, third_place) do
    get_option(key, first_place, second_place) || get_option(key, third_place)
  end

end
