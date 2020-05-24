## filebeat
describe 'Unit testing' {

    $serviceName = 'filebeat'
    Context ': Checking if filebeat service is running ' {
    $status = (Get-Service $serviceName).Status

    it 'Service is running!' {
        $status | should -Be 'Running'

    }
  }
}

## winlogbeat
describe 'Unit testing' {

    $serviceName = 'winlogbeat'
    Context ': Checking if winlogbeat service is running ' {
    $status = (Get-Service $serviceName).Status

    it 'Service is running!' {
        $status | should -Be 'Running'

    }
  }
}
## ADInvigilator service
describe 'Unit testing' {

    $serviceName = 'ADInvigilator'
    Context ': Checking if ADInvigilator service is running ' {
    $status = (Get-Service $serviceName).Status

    it 'Service is running!' {
        $status | should -Be 'Running'

    }
  }
}

## ADInvigilator-Frequent service 

describe 'Unit testing' {

    $serviceName = 'ADInvigilator-Frequent'
    Context ': Checking if ADInvigilator-Frequent service is running ' {

    $status = (Get-Service $serviceName).Status

    it 'Service is running!' {
        $status | should -Be 'Running'

    }
  }
}

Describe  'Unit testing' {

$PreviousScan = 'C:\ADInvigilator\compare_csv\classificationChange\PrieviousScan'

    Context ': Checking the classfication compare file exists' {

        It 'classfication compare file found!' {
            $PreviousScan | Should -Exist
        }

    }
}

Describe  'Unit testing' {

$exportPreviousScan = "C:\ADInvigilator\compare_csv\adminCount\PreviousScan.csv"

    Context ': Checking the admin count compare file exists' {

        It 'admin count compare file found!' {
            $exportPreviousScan | Should -Exist
        }

    }
}