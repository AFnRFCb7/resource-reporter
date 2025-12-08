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
                                    repo ,
                                    resolution ,
                                    type
                                } :
                                    let
                                        application =
                                            pkgs.writeShellApplication
                                                {
                                                    name = "resource-reporter" ;
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
                                                                                        TOKEN=${ resources.production.secrets.token ( setup : setup ) }
                                                                                        gh auth login --with-token < "$TOKEN/secret"
                                                                                        if ! gh label list --json name --jq '.[].name' | grep -qx resource-reporter-scripted
                                                                                        then
                                                                                            gh label create resource-reporter-scripted --color "#FF8C00" --description "Scripted by resource-reporter"
                                                                                        fi
                                                                                        gh issue create --repo "${ repo }" --title "$TITLE" --body "$BODY" --assignee "@me" --label resource-reporter-scripted
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
                                                                        if [[ "${ type } == "$TYPE_" ]] && ( [[ "resolve-init" == "$TYPE_" ]] || [[ "resolve-release" == "$TYPE_" ]] )
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
                                        in "${ application }/bin/resource-reporter" ;
                            in
                                {
                                    check =
                                        {
                                            channel ? "a44d2223" ,
                                            expected ? "6ad72035" ,
                                            repo ? "f6a56b94" ,
                                            resolution ? "a66ecc33" ,
                                            type ? "4934525a"
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
                                                                                        repo = repo ;
                                                                                        resolution = resolution ;
                                                                                        type = type ;
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
                                                                                            failure 8c67cfa1 resource-releaser "We expected to see ${ expected } but we observed ${ observed }"
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