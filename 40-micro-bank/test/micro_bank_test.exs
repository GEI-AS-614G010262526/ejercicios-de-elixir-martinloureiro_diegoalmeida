defmodule MicroBankTest do
  use ExUnit.Case, async: true

  describe "secuencias válidas" do
    setup do
      name = :"bank_#{System.unique_integer([:positive])}"
      pid = start_supervised!({MicroBank, name: name})
      {:ok, bank: name, pid: pid}
    end

    test "deposit -> ask -> withdraw -> ask", %{bank: bank} do
      assert {:ok, 100} = MicroBank.deposit(bank, "paco", 100)
      assert {:ok, 100} = MicroBank.ask(bank, "paco")
      assert {:ok, 60} = MicroBank.withdraw(bank, "paco", 40)
      assert {:ok, 60} = MicroBank.ask(bank, "paco")
    end

    test "varios depositos suman correctamente", %{bank: bank} do
      assert {:ok, 100} = MicroBank.deposit(bank, "paco", 100)
      assert {:ok, 300} = MicroBank.deposit(bank, "paco", 200)
      assert {:ok, 300} = MicroBank.ask(bank, "paco")
    end

    test "withdraw deja el balance en 0 si se retira todo", %{bank: bank} do
      assert {:ok, 100} = MicroBank.deposit(bank, "paco", 100)
      assert {:ok, 0} = MicroBank.withdraw(bank, "paco", 100)
      assert {:ok, 0} = MicroBank.ask(bank, "paco")
    end
  end

  describe "secuencias inválidas" do
    setup do
      name = :"bank_#{System.unique_integer([:positive])}"
      pid = start_supervised!({MicroBank, name: name})
      {:ok, bank: name, pid: pid}
    end

    test "withdraw con fondos insuficientes", %{bank: bank} do
      assert {:ok, 50} = MicroBank.deposit(bank, "maria", 50)
      assert {:error, :insufficient_funds} = MicroBank.withdraw(bank, "maria", 100)
    end

    test "withdraw de cuenta inexistente", %{bank: bank} do
      assert {:error, :insufficient_funds} = MicroBank.withdraw(bank, "juan", 100)
    end
  end

  describe "supervisor" do
    test "reinicia el proceso si termina de forma repentina" do
      name = :"bank_#{System.unique_integer([:positive])}"

      {:ok, _sup_pid} =
        Supervisor.start_link(
          [
            {MicroBank, name: name}
          ],
          strategy: :one_for_one
        )
      pid1 = Process.whereis(name)
      assert is_pid(pid1)
      Process.exit(pid1, :kill)
      Process.sleep(50)
      pid2 = Process.whereis(name)
      assert is_pid(pid2)
      refute pid1 == pid2
    end
  end
end
