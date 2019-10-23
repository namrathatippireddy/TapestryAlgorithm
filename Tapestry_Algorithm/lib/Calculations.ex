defmodule Utils do
  def nextHop(n,g,self,rt) do
    if n == length(rt) do
      self
    else
      d = Enum.at(String.codepoints(g), n)
      e = rt[n][d]
      while e == nil do
        d = d + 1
        e = rt[n][d]
      end
      if e == self do
        nextHop(n + 1,g,self,rt)
      else
        e
      end
    end
  end

  def tableInit(n) do
    Enum.reduce(0..n, %{}, fn x, acc -> Map.put(acc, x,
      Enum.reduce(0..15, %{}, fn y, acc1 -> Map.put(acc1,Integer.to_string(y, 16),nil) end)) end)
  end

end
