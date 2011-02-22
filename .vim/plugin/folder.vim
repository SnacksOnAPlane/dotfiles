
function! FindParentFolds()
  let initialline = line('.')
	let initialcol = col(".")
	let leastfolded = foldlevel(initialline)
  while 1
    let prevline = line('.')
    normal! k
    let currline = line('.')
    if foldlevel(currline) < leastfolded
			echo foldlevel(currline).": ".getline(prevline)
			let leastfolded = foldlevel(currline)
		endif
		if foldlevel(currline) < 1
			break
		endif
  endwhile
	call cursor(initialline, initialcol)
endfunction
