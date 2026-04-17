#!/usr/bin/env bats

setup_file() {
    mv -f .cqfd/docker/Dockerfile .cqfd/docker/Dockerfile.old
    cp -f .cqfdrc .cqfdrc.old
    cp -f cqfdrc-external_docker_image .cqfdrc
    export external_docker_image="ubuntu:16.04"
    #shellcheck disable=SC2154
    if "$cqfd_docker" inspect "$external_docker_image"; then
        "$cqfd_docker" rmi "$external_docker_image"
    fi
}

setup() {
    load 'test_helper/common-setup'
    _common_setup
}

teardown_file() {
    mv -f .cqfdrc.old .cqfdrc
    mv -f .cqfd/docker/Dockerfile.old .cqfd/docker/Dockerfile
}

@test "'cqfd' does not pull image" {
    run cqfd
    assert_failure
}

@test "'cqfd init' pulls image" {
    run cqfd init
    assert_success
    run "$cqfd_docker" inspect "$external_docker_image"
    assert_success
}

@test "'cqfd' uses pulled image" {
    run cqfd
    assert_success
    assert_line --regexp "Ubuntu 16.04(.[[:digit:]]+)? LTS"
}

@test "'cqfd run' reports outdated image" {
    if "$cqfd_docker" inspect "$external_docker_image"; then
        "$cqfd_docker" rmi "$external_docker_image"
    fi
    "$cqfd_docker" pull ubuntu:16.04@sha256:d388ba452d5f3f29399fc38c6928a65e4f28328a413c2edeee354569e7ab9bc9
    "$cqfd_docker" image tag ubuntu:16.04@sha256:d388ba452d5f3f29399fc38c6928a65e4f28328a413c2edeee354569e7ab9bc9 ubuntu:16.04
    run cqfd
    assert_success
    assert_line --regexp "Ubuntu 16.04(.[[:digit:]]+)? LTS"
    assert_line "cqfd: warning: The docker image is outdated, launch 'cqfd init' to update it"
}
