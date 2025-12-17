document.addEventListener('DOMContentLoaded',()=>{
  const numSubjectsEl = document.getElementById('numSubjects');
  const setBtn = document.getElementById('setSubjects');
  const subjectsContainer = document.getElementById('subjectsContainer');
  const marksForm = document.getElementById('marksForm');
  const calculateBtn = document.getElementById('calculate');
  const resetBtn = document.getElementById('reset');
  const resultDiv = document.getElementById('result');

  function clearSubjects(){
    subjectsContainer.innerHTML = '';
    resultDiv.classList.add('hidden');
  }

  function createSubjectRow(index){
    const row = document.createElement('div');
    row.className = 'subject-row';

    const nameInput = document.createElement('input');
    nameInput.type = 'text';
    nameInput.placeholder = `Subject ${index + 1}`;
    nameInput.value = `Subject ${index + 1}`;

    const markInput = document.createElement('input');
    markInput.type = 'number';
    markInput.min = '0';
    markInput.max = '100';
    markInput.placeholder = 'Marks (0-100)';

    row.appendChild(nameInput);
    row.appendChild(markInput);
    return row;
  }

  setBtn.addEventListener('click',()=>{
    const n = parseInt(numSubjectsEl.value,10);
    if(!n || n < 1){
      alert('Enter a valid number of subjects (>=1)');
      return;
    }
    clearSubjects();
    for(let i=0;i<n;i++) subjectsContainer.appendChild(createSubjectRow(i));
    marksForm.classList.remove('hidden');
  });

  calculateBtn.addEventListener('click',()=>{
    const rows = subjectsContainer.querySelectorAll('.subject-row');
    if(rows.length === 0){ alert('Please set number of subjects first.'); return; }

    let total = 0;
    const perSubjectMax = 100;
    const details = [];
    let invalid = false;

    rows.forEach((row,idx)=>{
      const name = row.children[0].value.trim() || `Subject ${idx+1}`;
      const markStr = row.children[1].value.trim();
      const mark = Number(markStr);
      if(markStr === '' || Number.isNaN(mark) || mark < 0 || mark > perSubjectMax){
        invalid = true;
      } else {
        total += mark;
        details.push({name,mark});
      }
    });

    if(invalid){
      resultDiv.classList.remove('hidden');
      resultDiv.innerHTML = `<div class="error">Please enter valid marks (0 to 100) for every subject.</div>`;
      return;
    }

    const subjectCount = rows.length;
    const maxTotal = subjectCount * perSubjectMax;
    const percentage = (total / maxTotal) * 100; // out of 100

    function gradeFromPct(p){
      if(p >= 90) return 'A+';
      if(p >= 80) return 'A';
      if(p >= 70) return 'B';
      if(p >= 60) return 'C';
      if(p >= 50) return 'D';
      return 'F';
    }

    const grade = gradeFromPct(percentage);

    resultDiv.classList.remove('hidden');
    resultDiv.innerHTML = `
      <div class="result-value"><strong>Total:</strong> ${total} / ${maxTotal}</div>
      <div class="result-value"><strong>Percentage:</strong> ${percentage.toFixed(2)}%</div>
      <div class="result-value"><strong>Grade:</strong> ${grade}</div>
      <hr>
      <div><strong>Breakdown:</strong></div>
      <ul>${details.map(d=>`<li>${escapeHtml(d.name)}: ${d.mark}</li>`).join('')}</ul>
    `;
  });

  resetBtn.addEventListener('click',()=>{
    numSubjectsEl.value = 3;
    marksForm.classList.add('hidden');
    clearSubjects();
  });

  function escapeHtml(str){
    return str.replace(/[&<>\"']/g, function(m){ return ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'})[m]; });
  }

});
