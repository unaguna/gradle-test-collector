#shellcheck shell=sh

Describe 'sample'
  Describe 'calc()'
    calc() { echo "$(($*))"; }

    It 'calculates the formula'
      When call calc 1 + 2
      The output should equal 3
    End
  End
End
