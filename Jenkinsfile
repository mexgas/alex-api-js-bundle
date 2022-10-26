pipeline {
    agent any
    environment {
        PROJECT_ENVIRONMENT = 'DEVELOP'
        SONAR_NAME = 'CW_Data_Base_DEV'
    }
    stages {
        stage('Setup parameters') {
            steps {
                script {
                    properties([
                        parameters([
                             string(
                                name: '__RELEASE_VERSION',
                                defaultValue: '124.01-4_20221020_1',
                                trim: true
                            )
                        ])
                    ])
                }
            }
        }
        stage('Parameters:'){
            steps{
                params.each() { param, value ->
                    print "Parameter: ${param}, Value: ${value}"
                }
            }
        }
        stage('slack notification') {
            when { anyOf { branch 'develop'; branch 'release/*'; branch 'hotfix/*'; branch 'master' } }
            steps {
                notifyBuild('STARTED')
            }
        }

        stage('Publish Ftp CCenterRIA') {
            when { anyOf { branch 'develop'; branch 'release/*'; branch 'hotfix/*'; } }
            steps {
            
                sshPublisher(publishers: [sshPublisherDesc(configName: 'SFTP Dev46', transfers: [
                    sshTransfer(cleanRemote: true, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+',
                    remoteDirectory: 'cw/$__RELEASE_VERSION/UpdateDB', remoteDirectorySDF: false,
                    removePrefix: '/CCenterRIA/UpdateDB/',
                    sourceFiles: '/CCenterRIA/UpdateDB/*.sql')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])

                sshPublisher(publishers: [sshPublisherDesc(configName: 'SFTP Dev46', transfers: [
                    sshTransfer(cleanRemote: false, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+',
                    remoteDirectory: 'cw/$__RELEASE_VERSION/Database', remoteDirectorySDF: false,
                    removePrefix: '/CCenterRIA/',
                    sourceFiles: '/CCenterRIA/CCenterRIA*.*')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }

        stage('Publish Ftp CCReportsRIA') {
            when { anyOf { branch 'develop'; branch 'release/*'; branch 'hotfix/*'; } }
            steps {
               
                sshPublisher(publishers: [sshPublisherDesc(configName: 'SFTP Dev46', transfers: [
                    sshTransfer(cleanRemote: true, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+',
                    remoteDirectory: 'cw/$__RELEASE_VERSION/ReportsRia/UpdateDB', remoteDirectorySDF: false,
                    removePrefix: '/ccReportsRia/UpdateDB/',
                    sourceFiles: '/ccReportsRia/UpdateDB/*.sql')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])

                sshPublisher(publishers: [sshPublisherDesc(configName: 'SFTP Dev46', transfers: [
                    sshTransfer(cleanRemote: false, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+',
                    remoteDirectory: 'cw/$__RELEASE_VERSION/ReportsRia/Database', remoteDirectorySDF: false,
                    removePrefix: '/ccReportsRia/',
                    sourceFiles: '/ccReportsRia/ccReportsRia*.*')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }

        stage('Publish Ftp AVRS') {
            when { anyOf { branch 'develop'; branch 'release/*'; branch 'hotfix/*'; } }
            steps {
               
                sshPublisher(publishers: [sshPublisherDesc(configName: 'SFTP Dev46', transfers: [
                    sshTransfer(cleanRemote: true, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+',
                    remoteDirectory: 'cw/$__RELEASE_VERSION/AVRS/UpdateDB', remoteDirectorySDF: false,
                    removePrefix: '/RecorderRIA/UpdateDB/',
                    sourceFiles: '/RecorderRIA/UpdateDB/*.sql')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }

        stage('Publish Ftp Jobs') {
            when { anyOf { branch 'develop'; branch 'release/*'; branch 'hotfix/*';} }
            steps {
                
                sshPublisher(publishers: [sshPublisherDesc(configName: 'SFTP Dev46', transfers: [
                    sshTransfer(cleanRemote: true, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+',
                    remoteDirectory: 'cw/$__RELEASE_VERSION/Jobs', remoteDirectorySDF: false,
                    removePrefix: '/Jobs/',
                    sourceFiles: '/Jobs/*.sql')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])

                    sshPublisher(publishers: [sshPublisherDesc(configName: 'SFTP Dev46', transfers: [
                    sshTransfer(cleanRemote: true, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+',
                    remoteDirectory: 'cw/$__RELEASE_VERSION/SQLTools/', remoteDirectorySDF: false,
                    removePrefix: '/SQLTools/',
                    sourceFiles: '/SQLTools/*.sql')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }

        stage('Publish Ftp Replication') {
            when { anyOf { branch 'develop'; branch 'release/*'; branch 'hotfix/*';} }
            steps {

                sshPublisher(publishers: [sshPublisherDesc(configName: 'SFTP Dev46', transfers: [
                    sshTransfer(cleanRemote: false, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+',
                    remoteDirectory: 'cw/$__RELEASE_VERSION/SQLTools/Replication', remoteDirectorySDF: false,
                    removePrefix: '/Replication/',
                    sourceFiles: '/Replication/**/*.sql')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }
    }
    post {
        success {
            notifyBuild('SUCCESS')
            cleanWs()
        }
        failure {
            notifyBuild('FAIL')
        }
    }
}

def notifyBuild(String buildStatus = 'STARTED') {
    // build status of null means successful
    buildStatus = buildStatus ?: 'SUCCESS'

    // Default values
    def colorCode = '#FF0000'
    def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
    def summary = "${subject} (${env.BUILD_URL})"

    // Override default values based on build status
    if (buildStatus == 'STARTED') {
        color = 'YELLOW'
        colorCode = '#FFFF00'
  } else if (buildStatus == 'SUCCESS') {
        color = 'GREEN'
        colorCode = '#00FF00'
  } else {
        color = 'RED'
        colorCode = '#FF0000'
    }

    // Send notifications
    slackSend(color: colorCode, message: summary)
}
