defmodule SentryHelpersTest do
  use ExSpec
  doctest Sentry.Helpers

  alias Sentry.Helpers, as: SH

  describe "verify_policy!" do
    defmodule FirstTestPolicy do
    end

    it "makes sure that the policy module is actually defined" do
      assert SH.verify_policy!(FirstTestPolicy) == FirstTestPolicy
    end

    it "raises for undefined policies" do
      assert_raise Sentry.Exception.UndefinedPolicyError, "undefined policy: NonExistingPolicy.", fn ->
        SH.verify_policy!(NonExistingPolicy)
      end
    end
  end

  describe "policy_module" do
    it "returns the conventional policy name, like: Bla -> BlaPolicy" do
      assert SH.policy_module(Users) == UsersPolicy
      assert SH.policy_module(User) == UserPolicy
      assert SH.policy_module(Bla) == BlaPolicy
    end

    it "also works with nested modules" do
      assert SH.policy_module(MyApp.Users) == MyApp.UsersPolicy
    end
  end


  describe "apply_policy" do
    defmodule ApplyTestPolicy do
      def show?(user, doc) do
        doc.user_id == user.id
      end
    end

    it "correctly calls a function on a given policy module" do
      user = %{id: 1, name: "some user"}
      doc  = %{id: 2, user_id: 1, name: "some doc"}
      assert SH.apply_policy(ApplyTestPolicy, :show?, [user, doc]) == true
      assert SH.apply_policy(ApplyTestPolicy, :show?, [%{user | id: 2}, doc]) == false
    end
  end
end
