{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        failure ,
                        pkgs
                    } :
                        let
                            implementation =
                                {
                                    channel ,
                                    description ,
                                    enable ,
                                    organization ,
                                    repository ,
                                    resolution ,
                                    token ,
                                    user
                                } :
                                    {
                                        service =
                                            {
                                                after = [ "network.target" "redis.service" ] ;
                                                description = description ;
                                                enable = enable ;
                                                serviceConfig =
                                                    {
                                                        ExecStart =
                                                            let
                                                                application =
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "ExecStart" ;
                                                                            runtimeInputs =
                                                                                [
                                                                                    pkgs.redis
                                                                                    pkgs.yq-go
                                                                                    failure
                                                                                    (
                                                                                        pkgs.writeShellApplication
                                                                                            {
                                                                                                name = "iteration" ;
                                                                                                runtimeInputs =
                                                                                                    [
                                                                                                        pkgs.gh
                                                                                                        failure
                                                                                                    ] ;
                                                                                                text =
                                                                                                    let
                                                                                                        in
                                                                                                            ''
                                                                                                                TITLE="Automatic Title"
                                                                                                                BODY="Automatic Body"
                                                                                                                if [[ "$#" -gt 0 ]]
                                                                                                                then
                                                                                                                    TITLE="$1"
                                                                                                                    shift
                                                                                                                fi
                                                                                                                if [[ "$#" -gt 0 ]]
                                                                                                                then
                                                                                                                    BODY="$*"
                                                                                                                fi
                                                                                                                TOKEN=${ token }
                                                                                                                gh auth login --with-token < "$TOKEN/secret"
                                                                                                                if ! gh label list --json name --jq '.[].name' | grep -qx resource-reporter-scripted
                                                                                                                then
                                                                                                                    gh label create resource-reporter-scripted --color "#FF8C00" --description "Scripted by resource-reporter"
                                                                                                                fi
                                                                                                                gh issue create --repo "${ organization }/${ repository }" --title "$TITLE" --body "$BODY" --assignee "@me" --label resource-reporter-scripted
                                                                                                                gh auth logout
                                                                                                            '' ;
                                                                                            }
                                                                                    )
                                                                                ] ;
                                                                            text =
                                                                                ''
                                                                                    redis-cli SUBSCRIBE ${ channel } | while read -r TYPE
                                                                                    do
                                                                                        if [[ "$TYPE" == "message" ]]
                                                                                        then
                                                                                            read -r CHANNEL
                                                                                            if [[ ${ channel } == "$CHANNEL" ]]
                                                                                            then
                                                                                                read -r PAYLOAD
                                                                                                TYPE_="$( yq eval ".type" <<< "$PAYLOAD" - )" || failure 2ee1309a
                                                                                                if [[ "resolve-init" == "$TYPE_" ]] || [[ "resolve-release" == "$TYPE_" ]]
                                                                                                then
                                                                                                    RESOLUTION="$( yq eval ".resolution" - <<< "$PAYLOAD" )" || failure 629c9f6a
                                                                                                    if [[ "${ resolution }" == "$RESOLUTION" ]]
                                                                                                    then
                                                                                                        ARGUMENTS_JSON="$( yq eval ".arguments // [ ]" - <<< "$PAYLOAD" )" || failure c9430185
                                                                                                        readarray -t ARGUMENTS <<< "$ARGUMENTS_JSON"
                                                                                                        iteration "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }"
                                                                                                    fi
                                                                                                fi
                                                                                            fi
                                                                                        fi
                                                                                    done
                                                                                '' ;
                                                                        } ;
                                                                in "${ application }/bin/ExecStart" ;
                                                        User = user ;
                                                    } ;
                                                wantedBy = [ "multi-user.target" ] ;
                                            } ;
                                    } ;
                            in
                                {
                                    check =
                                        {
                                            channel ? "a44d2223" ,
                                            description ? "7a599edb" ,
                                            enable ? "6a430d15" ,
                                            expected ? "6ad72035" ,
                                            organization ? "915e3f48" ,
                                            repository ? "f6a56b94" ,
                                            resolution ? "a66ecc33" ,
                                            token ? "fccebd6d" ,
                                            user ? "42cb83c2"
                                        } :
                                            pkgs.stdenv.mkDerivation
                                                {
                                                    installPhase = ''execute-test "$out"'' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                let
                                                                    observed =
                                                                        builtins.toString
                                                                            (
                                                                                implementation
                                                                                    {
                                                                                        channel = channel ;
                                                                                        description = description ;
                                                                                        enable = enable ;
                                                                                        organization = organization ;
                                                                                        repository = repository ;
                                                                                        resolution = resolution ;
                                                                                        token = token ;
                                                                                        user = user ;
                                                                                    }
                                                                            ) ;
                                                                    in
                                                                        if expected == observed then
                                                                            pkgs.writeShellApplication
                                                                                {
                                                                                    name = "execute-test" ;
                                                                                    runtimeInputs = [ pkgs.coreutils ] ;
                                                                                    text =
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        '' ;
                                                                                }
                                                                        else
                                                                            pkgs.writeShellApplication
                                                                                {
                                                                                    name = "execute-test" ;
                                                                                    runtimeInputs = [ failure ] ;
                                                                                    text =
                                                                                        ''
                                                                                            failure 8c67cfa1 resource-reporter "We expected expected to be observed" "EXPECTED=${ builtins.toFile "expected.json" ( builtins.toJSON expected ) }" "OBSERVED=${ builtins.toFile "observed.json" ( builtins.toJSON observed ) }"
                                                                                        '' ;
                                                                                }
                                                            )
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}