.PHONY : test
test :
	cargo test

.PHONY: create-branch
create-branch :
ifneq ($(issue),)
	git checkout -b ISSUE-$(issue)
	git push --set-upstream origin $$(git branch | grep \* | cut -d ' ' -f2)
else ifneq ($(name),)
	git checkout -b $(name)
	git push --set-upstream origin $$(git branch | grep \* | cut -d ' ' -f2)
else
	$(error must supply 'issue' or 'name' parameter)
endif

.PHONY : delete-branch
delete-branch :
	@BRANCH=`git rev-parse --abbrev-ref HEAD` \
		&& [ $$BRANCH != 'code' ] \
		&& echo "On branch $$BRANCH" \
		&& echo "Checking out code" \
		&& git checkout code \
		&& git pull \
		&& echo "Deleting branch $$BRANCH" \
		&& git branch -d $$BRANCH \
		&& git remote prune origin
